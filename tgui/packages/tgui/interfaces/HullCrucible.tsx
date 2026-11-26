import { useBackend } from 'tgui/backend';
import { Box, Button, Flex, Knob } from 'tgui/components';

import { Window } from '../layouts';
import { MaterialAccessBar } from './Fabrication/MaterialAccessBar';
import { Material } from './Fabrication/Types';

type Data = {
  nanite_cans: NaniteCan[];
  materials: Material[];
  alloy_types: string[];
  selected_alloy: string;
  throttle: number;
};

type NaniteCan = {
  nanites: number;
};

export const HullCrucible = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    nanite_cans = [],
    materials = [],
    alloy_types = [],
    selected_alloy = '',
    throttle,
  } = data;
  return (
    <Window width={500} height={300}>
      <Window.Content>
        <Flex height="100%" direction="column">
          {nanite_cans.map((can) => (
            <p key={can}>{can.nanites}</p>
          ))}
          <Flex.Item grow>
            <Flex
              style={{
                border: '1px solid grey',
                justifyContent: 'center',
                flexWrap: 'wrap',
              }}
            >
              {alloy_types.map((alloy) => (
                <Flex.Item key={alloy} m={1}>
                  <Button
                    width="100px"
                    content={alloy}
                    selected={selected_alloy === alloy}
                    onClick={() => {
                      act('select_alloy', { alloy: alloy });
                    }}
                  />
                </Flex.Item>
              ))}
            </Flex>
            <Flex>
              <Flex.Item>
                <Box p={1}>
                  <Knob
                    size={1.5}
                    value={throttle}
                    minValue={0}
                    maxValue={1}
                    animated={false}
                    stepPixelSize={10}
                    step={0.1}
                    onChange={(_, v) => act('throttle', { throttle: v })}
                  />
                </Box>
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <MaterialAccessBar
            availableMaterials={materials || []}
            onEjectRequested={(material, amount) =>
              act('remove_mat', { ref: material.ref, amount })
            }
          />
        </Flex>
      </Window.Content>
    </Window>
  );
};
