import { useBackend } from '../backend';
import { Section } from '../components';
import { Window } from '../layouts';

export const AtmosIcafr = (props) => {
  const { act, data } = useBackend();
  const { reaction_energy, display_power, reaction_harvesting } = data;
  return (
    <Window theme="ntos" width={480} height={500}>
      <Window.Content>
        <Section title="ICAFR:" fill={1} overflow-y="scroll">
          Reaction Energy
          <br />
          {reaction_energy}
          <br />
          Output Power
          <br />
          {display_power}
        </Section>
      </Window.Content>
    </Window>
  );
};
