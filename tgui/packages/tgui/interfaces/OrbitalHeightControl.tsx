import { useEffect, useRef, useState } from 'react';
import {
  Box,
  Button,
  DraggableClickableControl,
  Flex,
  Knob,
  LabeledCounter,
  LabeledList,
  NumberInput,
  Section,
  Stack,
} from 'tgui/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type OrbitalData = {
  current_altitude: number;
  station_pos: number[];
  orbital_velocity: number[];
  semi_major_axis: number;
  eccentricity: number;
  arg_of_periapsis: number;
  station_target_angle: number;
  station_actual_angle: number;
  orbital_angle: number;
  orbital_items: OrbitalItem[];
  cinus_radius: number;
  cinus_name: string;
  cinus_grav_mass: number;
  atmosphere_height: number;
  atmosphere_normal: number;
  atmosphere_low: number;
  atmosphere_destruction: number;
  gain: number;
  integral: number;
  derivitive: number;
  last_error: number;
  accumulated_error: number;
  orbit_keeping: boolean;
  thrust_level: number;
  actual_thrust: number;
  error_over_time: number[];
};

type OrbitalItem = {
  name: string;
  radius: number;
  pos_x: number;
  pos_y: number;
};

type Simulation = {
  x: number;
  y: number;
  vx: number;
  vy: number;
};

export const OrbitalHeightControl = () => {
  return (
    <Window width={640} height={580}>
      <Window.Content
        style={{
          fontFamily: 'Consolas, "Courier New", monospace',
          background: 'linear-gradient(180deg, #0a0a0a 0%, #1a1a1a 100%)',
        }}
      >
        <OrbitalHeightContent />
      </Window.Content>
    </Window>
  );
};

const ErrorGraph = (props) => {
  const { error_over_time = [], width = 100, height = 100 } = props;

  return (
    <svg color="grey" width={width} height={height} viewBox={`${0} ${-25} ${50} ${50}`} style={{ backgroundColor: '#3a3a3a' }}>
      <g transform="scale(1, -1)">
        <rect height={1} width={50} x={0} y={0} fill="grey" />
        {error_over_time.map((error: number, i: number, array: number[]) => (
          <line
            key={i}
            x1={i - 1}
            y1={i > 0 ? array[i - 1] * 10 : 0}
            x2={i}
            y2={error * 10}
            stroke="red"
          />
        ))}
      </g>
    </svg>
  );
};

const OrbitalRing = (props) => {
  const {
    center_x,
    center_y,
    semi_major_axis,
    eccentricity,
    arg_of_periapsis,
    color,
    pixel_scale,
  } = props;
  const display_x = center_x * pixel_scale;
  const display_y = center_y * pixel_scale;
  const display_sma = semi_major_axis * pixel_scale;
  if (semi_major_axis <= 0 || eccentricity < 0 || eccentricity >= 1) {
    return null;
  }
  return (
    <ellipse
      cx={-(display_sma * eccentricity)}
      cy={0}
      rx={display_sma}
      ry={display_sma * Math.sqrt(1 - eccentricity * eccentricity)}
      fill="none"
      stroke={color}
      transform={`translate(${display_x} ${display_y}) rotate(${arg_of_periapsis})`}
    />
  );
};

function OrbitalObjectAnimation(
  origin_pos: number[],
  station_pos: any[],
  station_velo: number[],
  grav_mass: number,
  time_scale: number,
) {
  const sim = useRef({
    x: station_pos[0],
    y: station_pos[1],
    vx: station_velo[0],
    vy: station_velo[1],
  });

  const [position, set_position] = useState(station_pos);

  useEffect(() => {
    sim.current = {
      x: station_pos[0],
      y: station_pos[1],
      vx: station_velo[0],
      vy: station_velo[1],
    };
    set_position(station_pos);
  }, [station_pos[0], station_pos[1], station_velo[0], station_velo[1]]);

  useEffect(() => {
    let last_time = 0;
    let frame_id;
    function animate_object(current_time) {
      if (last_time === 0) last_time = current_time;
      let delta_time = (current_time - last_time) / 1000;
      last_time = current_time;
      sim.current = OrbitalObjectStep(
        origin_pos,
        [sim.current.x, sim.current.y],
        [sim.current.vx, sim.current.vy],
        delta_time * time_scale,
        grav_mass,
      );
      set_position([sim.current.x, sim.current.y]);
      frame_id = requestAnimationFrame(animate_object);
    }

    frame_id = requestAnimationFrame(animate_object);

    return () => {
      cancelAnimationFrame(frame_id);
    };
  }, [
    station_pos[0],
    station_pos[1],
    station_velo[0],
    station_velo[1],
    grav_mass,
  ]);
  return position;
}

function OrbitalObjectStep(
  origin_pos,
  step_pos,
  step_velo,
  delta_time,
  grav_mass,
): Simulation {
  let x = step_pos[0] - origin_pos[0];
  let y = step_pos[1] - origin_pos[1];
  let vx = step_velo[0];
  let vy = step_velo[1];

  let radius_squared = x ** 2 + y ** 2;
  let radius = Math.sqrt(radius_squared);

  if (radius === 0 || grav_mass <= 0) return { x: x, y: y, vx: vx, vy: vy };

  const ax = (-grav_mass * x) / (radius_squared * radius);
  const ay = (-grav_mass * y) / (radius_squared * radius);

  x = x + vx * delta_time + 0.5 * ax * delta_time ** 2;
  y = y + vy * delta_time + 0.5 * ay * delta_time ** 2;

  radius_squared = x ** 2 + y ** 2;
  radius = Math.sqrt(radius_squared);

  if (radius === 0) return { x: x, y: y, vx: vx, vy: vy };

  const next_ax = (-grav_mass * x) / (radius_squared * radius);
  const next_ay = (-grav_mass * y) / (radius_squared * radius);

  vx = vx + 0.5 * (ax + next_ax) * delta_time;
  vy = vy + 0.5 * (ay + next_ay) * delta_time;

  return {
    x: x + origin_pos[0],
    y: y + origin_pos[1],
    vx: vx,
    vy: vy,
  };
}

const OrbitalMap = (props) => {
  const { act, data } = useBackend<OrbitalData>();
  const {
    station_pos = [0, 0],
    orbital_velocity = [0, 0],
    semi_major_axis = 0,
    eccentricity = 0,
    arg_of_periapsis = 0,
    station_target_angle = 0,
    station_actual_angle = 0,
    orbital_angle,
    cinus_radius,
    cinus_grav_mass,
    atmosphere_height,
    atmosphere_normal,
    atmosphere_low,
    atmosphere_destruction,
  } = data;
  const { width = 300, height = 300 } = props;
  const pixel_scale = 1 / 40000;
  const sim = OrbitalObjectAnimation(
    [0, 0],
    station_pos,
    orbital_velocity,
    cinus_grav_mass,
    2,
  );
  const [pan_x, set_pan_x] = useState(0);
  const [pan_y, set_pan_y] = useState(0);
  const [zoom, set_zoom] = useState(1);

  return (
    <Section>
      <Box>
        <Knob
          size={1.5}
          value={zoom}
          minValue={0.1}
          maxValue={5}
          animated={false}
          step={0.1}
          onChange={(_, v) => set_zoom(v)}
        />
        <DraggableClickableControl
          value={pan_x}
          dragMatrix={[-1, 0]}
          step={1}
          stepPixelSize={1}
          onDrag={(e, value) => {
            set_pan_x(Math.min(Math.max(value, -width / 2), width));
          }}
          onClick={(e, value) => {}}
          updateRate={5}
        >
          {(control_x) => (
            <DraggableClickableControl
              value={pan_y}
              dragMatrix={[0, -1]}
              step={1}
              stepPixelSize={1}
              onDrag={(e, value) => {
                set_pan_y(Math.min(Math.max(value, -height / 2), height));
              }}
              onClick={(e, value) => {}}
              updateRate={5}
            >
              {(control_y) => (
                <svg
                  onMouseDown={(e) => {
                    control_x.handleDragStart(e);
                    control_y.handleDragStart(e);
                  }}
                  width={width}
                  height={height}
                  viewBox={`${(-(width / 2) + pan_x) * zoom} ${(-(height / 2) + pan_y) * zoom} ${width * zoom} ${height * zoom}`}
                >
                  <g transform="scale(1, -1)">
                    <line
                      x1={sim[0] * pixel_scale}
                      y1={sim[1] * pixel_scale}
                      x2={sim[0] * pixel_scale + 25}
                      y2={sim[1] * pixel_scale}
                      transform={`rotate(${station_actual_angle + orbital_angle} ${sim[0] * pixel_scale} ${sim[1] * pixel_scale})`}
                      stroke="red"
                    />
                    <line
                      x1={sim[0] * pixel_scale}
                      y1={sim[1] * pixel_scale}
                      x2={sim[0] * pixel_scale + 25}
                      y2={sim[1] * pixel_scale}
                      transform={`rotate(${station_target_angle + orbital_angle} ${sim[0] * pixel_scale} ${sim[1] * pixel_scale})`}
                      stroke="blue"
                    />
                    <OrbitalRing
                      center_x={0}
                      center_y={0}
                      semi_major_axis={semi_major_axis}
                      eccentricity={eccentricity}
                      arg_of_periapsis={arg_of_periapsis}
                      color="#ffffff"
                      pixel_scale={pixel_scale}
                    />
                    <circle
                      cx={0}
                      cy={0}
                      r={atmosphere_height * pixel_scale}
                      fill="#3284ff3d"
                    />
                    <circle
                      cx={0}
                      cy={0}
                      r={atmosphere_normal * pixel_scale}
                      fill="#54ff323d"
                    />
                    <circle
                      cx={0}
                      cy={0}
                      r={atmosphere_low * pixel_scale}
                      fill="#ffbe3285"
                    />
                    <circle
                      cx={0}
                      cy={0}
                      r={atmosphere_destruction * pixel_scale}
                      fill="#ff3232c7"
                    />
                    <circle
                      cx={0}
                      cy={0}
                      r={cinus_radius * pixel_scale}
                      fill="#e93c3c"
                    />
                    <rect
                      x={sim[0] * pixel_scale - 2}
                      y={sim[1] * pixel_scale - 2}
                      width={4}
                      height={4}
                      fill="grey"
                    />
                  </g>
                </svg>
              )}
            </DraggableClickableControl>
          )}
        </DraggableClickableControl>
      </Box>
    </Section>
  );
};

const OrbitKeeping = () => {
  const { act, data } = useBackend<OrbitalData>();
  const {
    gain,
    integral,
    derivitive,
    last_error,
    orbit_keeping,
    accumulated_error,
    error_over_time = [],
  } = data;

  return (
    <Flex direction="row">
      <Flex.Item>
        <Button
            content="Toggle Orbit Keeping"
            onClick={() => act('toggle_orbit_keeping')}
            align="center"
          />
          <Box>
          Orbit Keeping: {orbit_keeping ? "Activated" : "Deactivated"}
          </Box>
      </Flex.Item>
      <Flex.Item>
        <LabeledList>
          <LabeledList.Item label={"Gain"}>
            <Box m={1}>
        <NumberInput
          value={gain}
          minValue={0}
          maxValue={100}
          stepPixelSize={5}
          width="50px"
          step={0.01}
          onDrag={(value) =>
            act('gain', {
              gain: value,
            })
          }
        />
            </Box>
          </LabeledList.Item>
        <LabeledList.Item label={"Integral"}>
        <Box m={1} width="100%">
          <NumberInput
            value={integral}
            minValue={0.1}
            maxValue={100}
            stepPixelSize={5}
            width="50px"
            step={1}
            onDrag={(value) =>
              act('integral', {
                integral: value,
              })
            }
          />
        </Box>
        </LabeledList.Item>
        <LabeledList.Item label={"Derivitive"}>
        <Box m={1}>
          <NumberInput
            value={derivitive}
            minValue={0}
            maxValue={100}
            stepPixelSize={5}
            width="50px"
            step={0.1}
            onDrag={(value) =>
              act('derivitive', {
                derivitive: value,
              })
            }
          />
        </Box>
        </LabeledList.Item>
        </LabeledList>
        <Flex direction="row" backgroundColor="#680000" align="center">
        <LabeledCounter
          label="Accum. Error"
          todisplay={accumulated_error}
          maxdigits={8}
          fontSize="12px"
          backgroundColor="#680000"
        />
        <Box fill verticalAlign="center">
        <Button
          content={'Reset'}
          onClick={() => act('reset_integral')}
        />
        </Box>
        </Flex >
      </Flex.Item>
      <Flex.Item height="100%">

      <Flex direction="column">
        <ErrorGraph error_over_time={error_over_time} height="50%" />
        <LabeledCounter
          label="Error"
          todisplay={last_error}
          maxdigits={6}
          decimal={2}
          fontSize="12px"
          backgroundColor="#680000"
        />
      </Flex>
      </Flex.Item>
    </Flex>
  );
};

const Navball = () => {
  const { act, data } = useBackend<OrbitalData>();
  const { station_target_angle = 0 } = data;
  const ref = useRef<SVGSVGElement>(null);
  return (
    <Box
      width="150px"
      height="150px"
      m={2}
      style={{ border: '1px solid grey' }}
    >
      <Stack vertical align="center" fill>
        <Stack.Item>
          <Button
            mt="-10px"
            content={'Prograde'}
            onClick={() =>
              act('adjust_angle', {
                angle: 0,
              })
            }
          />
        </Stack.Item>
        <Stack.Item>
          <svg
            ref={ref}
            onMouseDown={(e) => {
              const parent = ref.current;
              if (!parent) return;
              const bounds = parent.getBoundingClientRect();
              act('adjust_angle', {
                angle:
                  Math.atan2(
                    e.clientX - bounds.left - bounds.width / 2,
                    e.clientY - bounds.top - bounds.height / 2,
                  ) *
                    (180 / Math.PI) -
                  180,
              });
            }}
            viewBox="-25 -25 50 50"
            height="100px"
            width="100px"
          >
            <g transform="scale(1, -1)">
              <line
                x1={0}
                y1={0}
                x2={0}
                y2={25}
                transform={`rotate(${station_target_angle} 0 0)`}
                stroke="blue"
              />
            </g>
          </svg>
        </Stack.Item>
        <Stack.Item>
          <Button
            mb="-10px"
            content={'Retrograde'}
            onClick={() =>
              act('adjust_angle', {
                angle: 180,
              })
            }
          />
        </Stack.Item>
      </Stack>
    </Box>
  );
};

const Throttle = () => {
  const { act, data } = useBackend<OrbitalData>();
  const { thrust_level, actual_thrust } = data;
  return (
    <Flex direction="row">
      <Flex.Item>
        <Stack vertical inline>
          <Button
            width="30px"
            icon="sort-up"
            onClick={() => act('increase_thrust')}
            align="center"
          />
          <Button
            width="30px"
            icon="sort-down"
            onClick={() => act('decrease_thrust')}
            align="center"
          />
        </Stack>
      </Flex.Item>
      <Flex.Item align="center" fill>
        <Box m={1}>Throttle: {thrust_level}</Box>
      </Flex.Item>
      <Flex.Item>
        <LabeledCounter
          label="Thrust"
          todisplay={actual_thrust / 1000000}
          maxdigits={10}
          fontSize="12px"
          backgroundColor="#182b5e"
          unit="MN"
        />
      </Flex.Item>
    </Flex>
  );
};

const OrbitalHeightContent = () => {
  const { act, data } = useBackend<OrbitalData>();
  return (
    <>
      <OrbitKeeping />
      <Throttle />
      <Navball />
      <OrbitalMap />
    </>
  );
};
